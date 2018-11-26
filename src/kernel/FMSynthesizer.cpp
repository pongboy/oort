#include <kernel/FMSynthesizer.hpp>
#include <kernel/drivers/Audio.hpp>
#include <cmath>

#include <iostream>
using namespace std;

#define PARAM_PER_ENVELOPE 12

Wave FMSynthesizer::wave;

FMSynthesizer::FMSynthesizer(uint8_t* mem, uint8_t note): mem(mem) {
    for (size_t o=0;o<SND_FM_OPERATORS;o++) {
        outputs[o] = 0;
        envelopes[o] = new Envelope(argptr16(o*PARAM_PER_ENVELOPE+0*sizeof(int16_t) +
                                             SND_FM_OPERATORS*sizeof(int16_t)),
                                    argptr16(o*PARAM_PER_ENVELOPE+1*sizeof(int16_t) +
                                             SND_FM_OPERATORS*sizeof(int16_t)),
                                    argptr16(o*PARAM_PER_ENVELOPE+2*sizeof(int16_t) +
                                             SND_FM_OPERATORS*sizeof(int16_t)),
                                    argptr16(o*PARAM_PER_ENVELOPE+3*sizeof(int16_t) +
                                             SND_FM_OPERATORS*sizeof(int16_t)),
                                    argptr16(o*PARAM_PER_ENVELOPE+4*sizeof(int16_t) +
                                             SND_FM_OPERATORS*sizeof(int16_t)),
                                    argptr16(o*PARAM_PER_ENVELOPE+5*sizeof(int16_t) +
                                             SND_FM_OPERATORS*sizeof(int16_t)));
    }

    base = 440.0*pow(1.059463094359, double(note-48));

    freqs = mem;
    amplitudes = mem +
                 PARAM_PER_ENVELOPE*SND_FM_OPERATORS +
                 SND_FM_OPERATORS*sizeof(int16_t);
}

FMSynthesizer::~FMSynthesizer() {
    for (size_t e=0;e<SND_FM_OPERATORS;e++) {
        delete envelopes[e];
    }
}

bool FMSynthesizer::done() {
    for (size_t e=0;e<SND_FM_OPERATORS;e++) {
        if (!envelopes[e]->done) {
            return false;
        }
    }

    return true;
}

void FMSynthesizer::on() {
    for (size_t e=0;e<SND_FM_OPERATORS;e++) {
        envelopes[e]->on();
    }
}

void FMSynthesizer::off() {
    for (size_t e=0;e<SND_FM_OPERATORS;e++) {
        envelopes[e]->off();
    }
}

void FMSynthesizer::fill(int16_t* samples, int16_t* clean, unsigned int sampleCount) {
    for (size_t s=0;s<sampleCount;s++) {
        int16_t delta = synthesize();

        // Mixa o canal anterior e o novo
#ifdef _WIN32
        bool overflow;
        int16_t result = delta + samples[s];

        if (delta < 0 && samples[s] < 0) {
            overflow = result >= 0;
        } else if (delta > 0 && samples[s] > 0) {
            overflow = result <= 0;
        }

        samples[s] = result;
#else
        bool overflow = __builtin_add_overflow(delta, samples[s], &samples[s]);
#endif

        // Corta overflow
        if (overflow) {
            samples[s] = (delta < 0) ? INT16_MIN : INT16_MAX;
        }

        int out = int(delta) + int(clean[s]);

        if (out < INT16_MIN) {
            clean[s] = INT16_MIN;
        } else if (out > INT16_MAX) {
            clean[s] = INT16_MAX;
        } else {
            clean[s] = out;
        }
    }
}

int16_t FMSynthesizer::synthesize() {
    // Itera sobre a matriz de operadores
    for (size_t o1=0;o1<SND_FM_OPERATORS;o1++) {
        uint16_t phase = times[o1];
        
        for (size_t o2=0;o2<SND_FM_OPERATORS;o2++) {
            auto i = o2*(SND_FM_OPERATORS+1)+o1;
            phase += outputs[o2]*Audio::tof16(amplitudes+i*sizeof(int16_t));
        }

        outputs[o1] = wave[phase] * envelopes[o1]->getAmplitude();
    }

    int16_t output = 0;

    for (size_t o=0;o<SND_FM_OPERATORS;o++) {
        // Avança os acumuladores de cada operador
        times[o] += Audio::tof16(freqs+o*sizeof(int16_t)) * base * float(UINT16_MAX)/float(44100);

        int16_t delta = outputs[o] * Audio::tof16(amplitudes+
                                                  o*(SND_FM_OPERATORS+1)*sizeof(int16_t)+
                                                  SND_FM_OPERATORS*sizeof(int16_t));

        // Mixa o operador anterior e o novo
#ifdef _WIN32
        bool overflow;
        int16_t result = delta + output;

        if (delta < 0 && output < 0) {
            overflow = result >= 0;
        } else if (delta > 0 && output > 0) {
            overflow = result <= 0;
        }

        output = result;
#else
        bool overflow = __builtin_add_overflow(delta, output, &output);
#endif

        // Corta overflow
        if (overflow) {
            output = (delta < 0) ? INT16_MIN : INT16_MAX;
        }
    }

    return output;
}

uint8_t* FMSynthesizer::argptr8(const size_t position) {
    return &mem[position];
}

int16_t* FMSynthesizer::argptr16(const size_t position) {
    return (int16_t*)(mem+position);
}

float FMSynthesizer::tof(uint8_t n) {
    return float(n);
}
